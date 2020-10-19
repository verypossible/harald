defmodule Harald.HCI.Commands.ControllerAndBaseband.WriteLocalNameTest do
  use ExUnit.Case, async: true
  alias Harald.HCI.{Commands, Commands.Command, Commands.ControllerAndBaseband}
  alias Harald.HCI.Commands.ControllerAndBaseband.WriteLocalName

  test "decode/1" do
    name = "bob"
    expected_name = String.pad_trailing(name, 248, <<0>>)
    expected_bin = <<1, 19, 12, 248, expected_name::binary>>
    local_name = String.pad_trailing(name, 248, <<0>>)

    expected_command = %Command{
      command_op_code: %{
        ocf: 19,
        ocf_module: WriteLocalName,
        ogf: 3,
        ogf_module: ControllerAndBaseband
      },
      parameters: %{read_local_name: local_name}
    }

    assert {:ok, expected_command} == Commands.decode(expected_bin)
  end

  test "encode/1" do
    name = "bob"
    expected_name = String.pad_trailing(name, 248, <<0>>)
    expected_bin = <<1, 19, 12, 248, expected_name::binary>>
    expected_size = byte_size(expected_bin)
    params = %{local_name: "bob"}
    {:ok, actual_bin} = Commands.encode(ControllerAndBaseband, WriteLocalName, params)
    assert expected_size == byte_size(actual_bin)
    assert expected_bin == actual_bin
  end
end
