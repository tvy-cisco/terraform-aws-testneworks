import select
import socket
import threading
import time

import paramiko

from logger_config import logger


class SSHTunnel:
    def __init__(
        self,
        jump_host,
        jump_port,
        jump_username,
        local_port,
        remote_host,
        remote_port,
    ):
        self.jump_host = jump_host
        self.jump_port = jump_port
        self.jump_username = jump_username
        self.local_port = local_port
        self.remote_host = remote_host
        self.remote_port = remote_port
        self.server_socket = None
        self.ssh_client = None
        self.running = False
        self.threads = []

    def __del__(self):
        """Ensure resources are cleaned up on deletion"""
        self.stop()

    def start(self):
        """Start the SSH tunnel in a separate thread"""
        thread = threading.Thread(target=self._start_tunnel, daemon=True)
        thread.start()
        self.threads.append(thread)

    def _start_tunnel(self):
        """Start the SSH tunnel"""
        # Create SSH client
        self.ssh_client = paramiko.SSHClient()
        self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        logger.debug(f"Connecting to Jump SSH server {self.jump_host}:{self.jump_port}")
        self.ssh_client.connect(
            hostname=self.jump_host,
            port=self.jump_port,
            username=self.jump_username,
            timeout=10,
        )

        # Create local server socket
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind(("localhost", self.local_port))
        self.server_socket.listen(5)

        self.running = True

        # Accept connections
        while True:
            try:
                client_socket, client_address = self.server_socket.accept()
                if not self.running:
                    logger.debug("SSH tunnel stopped, no longer accepting connections")
                    break
                logger.debug(f"New connection from {client_address}")

                # Handle each client in a separate thread
                thread = threading.Thread(
                    target=self.handle_client,
                    args=(client_socket, client_address),
                    daemon=True,
                )
                thread.start()
                self.threads.append(thread)

            except socket.error as e:
                if self.running:
                    logger.error(f"Error accepting connection: {e}")
                break

    def handle_client(self, client_socket, client_address):
        """Handle a single client connection"""
        ssh_channel = None
        try:
            # Create SSH channel for port forwarding
            ssh_channel = self.ssh_client.get_transport().open_channel(
                "direct-tcpip", (self.remote_host, self.remote_port), client_address
            )

            # Start forwarding threads
            forward_threads = []

            # Client to remote forwarding
            client_to_remote = threading.Thread(
                target=self.forward_data,
                args=(client_socket, ssh_channel, f"{client_address}->remote"),
                daemon=True,
            )
            client_to_remote.start()
            forward_threads.append(client_to_remote)

            # Remote to client forwarding
            remote_to_client = threading.Thread(
                target=self.forward_data,
                args=(ssh_channel, client_socket, f"remote->{client_address}"),
                daemon=True,
            )
            remote_to_client.start()
            forward_threads.append(remote_to_client)

            # Wait for forwarding to complete
            for thread in forward_threads:
                thread.join()

        except paramiko.SSHException as e:
            logger.error(f"Paramiko SSHException for {client_address}: {e}")
        except socket.error as e:
            logger.error(f"Socket error for {client_address}: {e}")
        except Exception as e:
            logger.error(f"Unexpected error for {client_address}: {e}")
        finally:
            # Clean up resources
            self.cleanup_connection(client_socket, ssh_channel, client_address)

    def forward_data(self, source, destination, direction):
        """Forward data between source and destination with proper error handling"""
        try:
            while True:
                # Use select for non-blocking check
                if hasattr(source, "fileno"):
                    ready, _, _ = select.select([source], [], [], 1.0)
                    if not ready:
                        # Check if connections are still alive
                        if (
                            not self.is_connection_alive(source)
                            or not self.is_connection_alive(destination)
                            or not self.running
                        ):
                            break
                        continue

                # Read data
                if isinstance(source, paramiko.Channel):
                    if source.recv_ready():
                        data = source.recv(4096)
                    else:
                        time.sleep(0.01)
                        continue
                else:
                    data = source.recv(4096)

                if not data:
                    logger.debug(f"Connection closed in direction {direction}")
                    break

                # Send data
                if isinstance(destination, paramiko.Channel):
                    destination.send(data)
                else:
                    destination.sendall(data)

        except (socket.error, paramiko.SSHException) as e:
            logger.warning(f"Connection error in {direction}: {e}")
        except Exception as e:
            logger.error(f"Unexpected error in {direction}: {e}")

    def is_connection_alive(self, conn):
        """Check if a connection is still alive"""
        try:
            if isinstance(conn, paramiko.Channel):
                return not conn.closed
            elif isinstance(conn, socket.socket):
                # Try to peek at the socket
                conn.settimeout(0.1)
                try:
                    data = conn.recv(1, socket.MSG_PEEK)
                    return True
                except socket.timeout:
                    return True
                except:
                    return False
                finally:
                    conn.settimeout(None)
            return False
        except:
            return False

    def cleanup_connection(self, client_socket, ssh_channel, client_address):
        """Clean up connection resources"""
        logger.debug(f"Cleaning up connection for {client_address}")

        if client_socket:
            try:
                client_socket.close()
            except:
                pass

        if ssh_channel:
            try:
                ssh_channel.close()
            except:
                pass

    def stop(self):
        """Stop the SSH tunnel and clean up resources"""
        self.running = False

        if self.server_socket:
            try:
                self.server_socket.close()
            except:
                pass

        if self.ssh_client:
            try:
                self.ssh_client.close()
            except:
                pass

        # Wait for threads to finish (with timeout)
        for thread in self.threads:
            thread.join(timeout=5)
