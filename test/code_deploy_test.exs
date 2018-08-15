defmodule CodeDeployTest do
  use ExUnit.Case
  doctest CodeDeploy

  test "greets the world" do
    assert CodeDeploy.hello() == :world
  end
end
