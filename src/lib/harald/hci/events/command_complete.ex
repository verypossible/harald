defmodule Harald.HCI.Events.CommandComplete do
  alias Harald.HCI.{Commands, Events.Event}

  @behaviour Event

  @impl Event
  def encode(%{
        num_hci_command_packets: num_hci_command_packets,
        command_op_code: command_op_code,
        return_parameters: return_parameters
      }) do
    return_parameters =
      case command_op_code.ocf_module do
        :not_implemented when is_binary(return_parameters) ->
          return_parameters

        ocf_module when ocf_module != :not_implemented ->
          {:ok, return_parameters} = ocf_module.encode_return_parameters(return_parameters)
          return_parameters
      end

    {:ok, command_op_code} = Commands.encode_op_code(command_op_code.ogf, command_op_code.ocf)

    ret = <<
      num_hci_command_packets,
      command_op_code::bytes-size(2),
      return_parameters::binary
    >>

    {:ok, ret}
  end

  @impl Event
  def decode(
        <<num_hci_command_packets, command_op_code::bytes-size(2), return_parameters::binary>>
      ) do
    {:ok, op_code} = Commands.decode_op_code(command_op_code)

    {command_op_code, return_parameters} =
      case Commands.ogf_to_module(op_code.ogf) do
        {:ok, ogf_module} ->
          case ogf_module.ocf_to_module(op_code.ocf) do
            {:ok, ocf_module} ->
              command_op_code =
                op_code
                |> Map.take([:ocf, :ogf])
                |> Map.merge(%{ocf_module: ocf_module, ogf_module: ogf_module})

              {:ok, return_parameters} = ocf_module.decode_return_parameters(return_parameters)
              {command_op_code, return_parameters}

            {:error, {:not_implemented, _}} ->
              {%{
                 ocf: op_code.ocf,
                 ocf_module: :not_implemented,
                 ogf: op_code.ogf,
                 ogf_module: ogf_module
               }, return_parameters}
          end

        {:error, {:not_implemented, _}} ->
          {%{
             ocf: op_code.ocf,
             ocf_module: :not_implemented,
             ogf: op_code.ogf,
             ogf_module: :not_implemented
           }, return_parameters}
      end

    parameters = %{
      num_hci_command_packets: num_hci_command_packets,
      command_op_code: command_op_code,
      return_parameters: return_parameters
    }

    {:ok, parameters}
  end

  @impl Event
  def event_code(), do: 0x0E
end
