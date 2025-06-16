import argparse
import json
import os
import threading
from typing import List, NamedTuple

import boto3
import paramiko
from logger_config import logger
from ssh_tunnel import SSHTunnel

ssh_tunnels = []

# def run_ssm_command(session, instance_id: str, command: str) -> None:
#     ssm = session.client("ssm", region_name="us-west-2")
#
#     response = ssm.send_command(
#         InstanceIds=[instance_id],
#         DocumentName="AWS-RunShellScript",
#         Parameters={"commands": [command]},
#     )
#
#     command_id = response["Command"]["CommandId"]
#
#     # To get the output
#     output = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
#
#     logger.info(output["StandardOutputContent"])
#
# def run_command_on_windows_instance(session, instance_id: str, command: str) -> None:
#     ssm = session.client("ssm", region_name="us-west-2")
#
#     response = ssm.send_command(
#         InstanceIds=[instance_id],
#         DocumentName="AWS-RunPowershellScript",
#         Parameters={"commands": [command]},
#     )
#
#     command_id = response["Command"]["CommandId"]
#
#     # To get the output
#     output = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
#
#     logger.info(output["StandardOutputContent"])


def run_ssh_commands_on_ec2(
    jumpServerIpv4: str,
    jumpServerUsername: str,
    host: str,
    username: str,
    commands: List[str],
) -> None:
    # Connect to jump host
    with paramiko.SSHClient() as jump_client:
        jump_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        jump_client.connect(jumpServerIpv4, username=jumpServerUsername)

        # Open channel from jump host to target
        transport = jump_client.get_transport()
        channel = transport.open_channel("direct-tcpip", (host, 22), ("", 0))
        with paramiko.SSHClient() as client:
            client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            client.connect(hostname=host, username=username, sock=channel)

            for command in commands:
                _, _, _ = client.exec_command(command)


# switches routing table for a network interface
# ipv6 only for now
def switch_routing_table(
    session, routing_table_id: str, network_interface: str
) -> None:
    ec2 = session.client("ec2", region_name="us-west-2")
    response = ec2.replace_route(
        RouteTableId=routing_table_id,
        DestinationIpv6CidrBlock="::/0",  # IPv6 default route
        NetworkInterfaceId=network_interface,
    )

    if response["ResponseMetadata"]["HTTPStatusCode"] != 200:
        raise Exception("Failed to replace route in routing table.")

    logger.info(
        f"Switched private routing table to {network_interface} for IPv6 traffic."
    )


class AwsInfo(NamedTuple):
    private_rt: str
    network5_gateway_interface: str
    network5_gateway_ipv6: str
    network4_gateway_interface: str
    network4_gateway_ipv6: str
    linux_test_instance_ipv6: str
    windows_test_instance_ipv6: str
    jumpbox_instance_ipv4: str
    mac_test_instance_ipv6: str


def get_aws_info() -> AwsInfo:
    if os.path.exists(
        "../terraform.tfstate"
    ):  # Check parent directory if not found in current
        with open("../terraform.tfstate", "r") as f:
            tfstate = json.load(f)
    else:
        raise FileNotFoundError("Terraform state file not found.")

    outputs = tfstate.get("outputs", [])
    return AwsInfo(
        private_rt=outputs["private_rt"]["value"],
        network5_gateway_interface=outputs["n5_gateway_network_interface_id"]["value"],
        network4_gateway_interface=outputs["n4_gateway_network_interface_id"]["value"],
        network5_gateway_ipv6=outputs["n5_gateway_ipv6"]["value"],
        network4_gateway_ipv6=outputs["n4_gateway_ipv6"]["value"],
        linux_test_instance_ipv6=outputs["linux_test_ip"]["value"],
        windows_test_instance_ipv6=outputs["windows_test_ip"]["value"],
        mac_test_instance_ipv6=outputs["mac_test_ip"]["value"],
        jumpbox_instance_ipv4=outputs["jumpbox_ip"]["value"],
    )


def run_vnc_tunnel(
    jump_host: str,
    jump_username: str,
    mac_ip6_address: str,
    local_port: int,
) -> None:

    vnc_tunnel = SSHTunnel(
        jump_host, 22, jump_username, local_port, windows_test_instance_ipv6, 5900
    )
    vnc_tunnel.start()
    logger.info(f"VNC SSH tunnel started on localhost:{local_port}")

    global ssh_tunnels
    ssh_tunnels.append(vnc_tunnel)


def run_rdp_ssh_tunnel(
    jump_host: str,
    jump_username: str,
    windows_test_instance_ipv6: str,
    local_port: int,
) -> None:

    rdp_tunnel = SSHTunnel(
        jump_host, 22, jump_username, local_port, windows_test_instance_ipv6, 3389
    )
    rdp_tunnel.start()
    logger.info(f"RDP SSH tunnel started on localhost:{local_port}")

    global ssh_tunnels
    ssh_tunnels.append(rdp_tunnel)


def wait_until_user_quits() -> None:
    try:
        logger.info("Press Ctrl+C or enter 'quit' to stop SSH tunnels...")
        while True:  # Keep the main thread alive to allow SSH tunnels to run
            userInput = input()  # Wait for user input to quit
            if userInput.lower() == "quit":
                raise KeyboardInterrupt
    except KeyboardInterrupt:
        logger.info("Quit received - Stopping SSH tunnels...")
        for tunnel in ssh_tunnels:
            tunnel.stop()
        logger.info("Goodbye!")


def main():
    parser = argparse.ArgumentParser(
        description="Switch network routes for an EC2 instance."
    )
    parser.add_argument(
        "network_test_number",
        type=int,
        help="Test network to switch to (1-7).",
    )
    args = parser.parse_args()

    if args.network_test_number < 1 or args.network_test_number > 7:
        raise ValueError("Network test number must be between 1 and 7.")

    aws_info = get_aws_info()
    session = boto3.Session(profile_name="strln")

    match args.network_test_number:
        case 4:
            logger.info(
                f"Switching to network test 4. {aws_info.network4_gateway_ipv6}"
            )
            switch_routing_table(
                session=session,
                routing_table_id=aws_info.private_rt,
                network_interface=aws_info.network4_gateway_interface,
            )
            run_ssh_commands_on_ec2(
                jumpServerIpv4=aws_info.jumpbox_instance_ipv4,
                jumpServerUsername="onprem-jenkins",
                host=aws_info.linux_test_instance_ipv6,
                username="admin",
                commands=[
                    "sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0",
                    "sudo sysctl -w net.ipv4.conf.all.disable_ipv4=1",
                    f"echo 'nameserver {aws_info.network4_gateway_ipv6}' | sudo tee /etc/resolv.conf > /dev/null",
                ],
            )
            logger.info(
                f"Switched Linux test machine to network 4 {aws_info.network4_gateway_ipv6}"
            )
            run_ssh_commands_on_ec2(
                jumpServerIpv4=aws_info.jumpbox_instance_ipv4,
                jumpServerUsername="onprem-jenkins",
                host=aws_info.windows_test_instance_ipv6,
                username="onprem-jenkins",
                commands=[
                    "powershell -Command Disable-NetAdapterBinding -Name 'Ethernet4' -ComponentID ms_tcpip",
                    "powershell -Command Enable-NetAdapterBinding -Name 'Ethernet4' -ComponentID ms_tcpip6",
                    f"powershell -Command Set-DnsClientServerAddress -InterfaceAlias 'Ethernet4' -ServerAddresses ('{aws_info.network4_gateway_ipv6}', '')",
                ],
            )
            logger.info(
                f"Switched Windows test machine to network 4 {aws_info.network4_gateway_ipv6}"
            )
            run_rdp_ssh_tunnel(
                jump_host=aws_info.jumpbox_instance_ipv4,
                jump_username="admin",
                windows_test_instance_ipv6=aws_info.windows_test_instance_ipv6,
                local_port=7077,  # Default RDP port
            )
        case 5:
            logger.info(f"Switching to network test 5 {aws_info.network5_gateway_ipv6}")
            switch_routing_table(
                session=session,
                routing_table_id=aws_info.private_rt,
                network_interface=aws_info.network5_gateway_interface,
            )
            run_ssh_commands_on_ec2(
                jumpserveripv4=aws_info.jumpbox_instance_ipv4,
                jumpserverusername="admin",
                host=aws_info.linux_test_instance_ipv6,
                username="admin",
                commands=[
                    "sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0",
                    "sudo sysctl -w net.ipv4.conf.all.disable_ipv4=1",
                    f"echo 'nameserver {aws_info.network5_gateway_ipv6}' | sudo tee /etc/resolv.conf > /dev/null",
                ],
            )
            logger.info(
                f"switched linux test machine to network 5 {aws_info.network5_gateway_ipv6}"
            )
            run_ssh_commands_on_ec2(
                jumpserveripv4=aws_info.jumpbox_instance_ipv4,
                jumpserverusername="admin",
                host=aws_info.windows_test_instance_ipv6,
                username="onprem-jenkins",
                commands=[
                    "powershell -command disable-netadapterbinding -name 'ethernet4' -componentid ms_tcpip",
                    "powershell -command enable-netadapterbinding -name 'ethernet4' -componentid ms_tcpip6",
                    f"powershell -command set-dnsclientserveraddress -interfacealias 'ethernet4' -serveraddresses ('{aws_info.network5_gateway_ipv6}', '')",
                ],
            )
            logger.info(
                f"switched windows test machine to network 5 {aws_info.network5_gateway_ipv6}"
            )
            run_rdp_ssh_tunnel(
                jump_host=aws_info.jumpbox_instance_ipv4,
                jump_username="admin",
                windows_test_instance_ipv6=aws_info.windows_test_instance_ipv6,
                local_port=7077,
            )
            run_vnc_tunnel(
                jump_host=aws_info.jumpbox_instance_ipv4,
                jump_username="admin",
                mac_ipv6_address=aws_info.mac_test_instance_ipv6,
                local_port=7066,
            )

        case _:
            raise ValueError("That test network is not implemented yet.")
    wait_until_user_quits()


if __name__ == "__main__":
    main()
