import argparse
from typing import NamedTuple

import boto3


def run_command_on_linux_instance(session, instance_id: str, command: str) -> None:
    ssm = session.client("ssm", region_name="us-west-2")

    response = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": [command]},
    )

    command_id = response["Command"]["CommandId"]

    # To get the output
    output = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)

    print(output["StandardOutputContent"])


def run_command_on_windows_instance(session, instance_id: str, command: str) -> None:
    ssm = session.client("ssm", region_name="us-west-2")

    response = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunPowershellScript",
        Parameters={"commands": [command]},
    )

    command_id = response["Command"]["CommandId"]

    # To get the output
    output = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)

    print(output["StandardOutputContent"])


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

    print(f"Switched private routing table to {network_interface} for IPv6 traffic.")


class InstanceIds(NamedTuple):
    private_rt: str
    network5_gateway_interface: str
    network5_gateway_ip: str
    network4_gateway_interface: str
    network4_gateway_ip: str
    linux_test_instance: str
    windows_test_instance: str


def get_instance_ids() -> InstanceIds:
    # TODO read ../.terraform.tfstate to get info to get better info
    # for now just hardcode the values
    return InstanceIds(
        private_rt="rtb-024ed52d79312f481",
        network5_gateway_interface="eni-0567eb468289a7719",
        network5_gateway_ip="2600:1f14:8e3:fc00:357e:dc53:3cf5:bd8f",
        network4_gateway_interface="eni-05ef45c1905165539",
        network4_gateway_ip="2600:1f14:8e3:fc00:ab74:df87:641a:a825",
        linux_test_instance="i-00e87fe3236e410b8",
        windows_test_instance="i-08f0b661979dfe4f7",
    )


def main():
    parser = argparse.ArgumentParser(
        description="Switch network routes for an EC2 instance."
    )
    parser.add_argument(
        "--network_test_number",
        required=True,
        type=int,
        help="Test network to switch to (1-7).",
    )
    args = parser.parse_args()

    if args.network_test_number < 1 or args.network_test_number > 7:
        raise ValueError("Network test number must be between 1 and 7.")

    instance_ids = get_instance_ids()
    session = boto3.Session(profile_name="strln")

    match args.network_test_number:
        case 4:
            print("Switching to network test 4.")
            switch_routing_table(
                session=session,
                routing_table_id=instance_ids.private_rt,
                network_interface=instance_ids.network4_gateway_interface,
            )
            # run commands on linux test instance to turn on IPv6 and off IPv4
            run_command_on_linux_instance(
                session=session,
                instance_id=instance_ids.linux_test_instance,
                command="sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0 && sudo sysctl -w net.ipv4.conf.all.disable_ipv4=1",
            )
            # run commands to rewrite resolv.conf to use instance_ids.network4_gateway_ip
            run_command_on_linux_instance(
                session=session,
                instance_id=instance_ids.linux_test_instance,
                command=f"echo 'nameserver {instance_ids.network4_gateway_ip}' | sudo tee /etc/resolv.conf > /dev/null",
            )
        case 5:
            print("Switching to network test 5.")
            switch_routing_table(
                session=session,
                routing_table_id=instance_ids.private_rt,
                network_interface=instance_ids.network5_gateway_interface,
            )
        case _:
            raise ValueError("Unknown network test number.")


if __name__ == "__main__":
    main()
