defmodule Petrovich.Store do
  @moduledoc """
  This module implements basic functionality for different agents.

  This module provides a simple macro, when it is used
  it inserts all the required `Agent`'s methods inside the
  caller module.
  """

  alias Petrovich.Config
  alias Petrovich.Exceptions.RulesFileException

  defmacro __using__(options) do
    caller = __CALLER__.module

    quote location: :keep, bind_quoted: [options: options, caller: caller] do
      @setting Keyword.get(options, :setting)
      @app :petrovich_elixir

      def start_link do
        Agent.start_link(&load_values/0, name: unquote(caller))
      end

      def stop do
        Agent.stop(unquote(caller))
      end

      def get(key) do
        Agent.get(unquote(caller), &Map.get(&1, key))
      end

      def all do
        Agent.get(unquote(caller), & &1)
      end

      defp load_values do
        @setting
        |> get_path()
        |> File.read!()
        |> get_json_codec().decode!()
      rescue
        e in File.Error ->
          reraise RulesFileException, System.stacktrace(),
            message: Exception.message(e)
      end

      defp get_path(:gender_path) do
        case Config.get_env(@app, :gender_path) do
          nil ->  Application.app_dir(@app, "priv/rules/gender.json")
          path -> path
        end
      end

      defp get_path(:rules_path) do
        case Config.get_env(@app, :rules_path) do
          nil -> Application.app_dir(@app, "priv/rules/rules.json")
          path -> path
        end
      end

      defp get_json_codec do
        Config.get_env(@app, :json_codec) || Jason
      end
    end
  end
end
