defmodule EnterpriseShop.Domain.OrderTest do
  use ExUnit.Case, async: true
  alias EnterpriseShop.Domain.Order

  describe "Order entity state transitions" do
    test "new order starts in :new state" do
      order = Order.new("order_1", %{"prod_1" => 2})
      assert order.state == :new
    end

    test "can transition from :new to :registered" do
      order = Order.new("order_1", %{"prod_1" => 2})
      assert {:ok, updated} = Order.transition(order, :register)
      assert updated.state == :registered
    end

    test "cannot transition from :new to :granted or :shipped" do
      order = Order.new("order_1", %{"prod_1" => 2})
      assert {:error, :invalid_transition} = Order.transition(order, :grant)
      assert {:error, :invalid_transition} = Order.transition(order, :ship)
    end

    test "can transition from :registered to :granted" do
      order = Order.new("order_1", %{"prod_1" => 2})
      {:ok, registered} = Order.transition(order, :register)

      assert {:ok, granted} = Order.transition(registered, :grant)
      assert granted.state == :granted
    end

    test "can transition from :registered to :cancelled" do
      order = Order.new("order_1", %{"prod_1" => 2})
      {:ok, registered} = Order.transition(order, :register)

      assert {:ok, cancelled} = Order.transition(registered, :cancel)
      assert cancelled.state == :cancelled
    end

    test "can transition from :granted to :shipped" do
      order = Order.new("order_1", %{"prod_1" => 2})
      {:ok, registered} = Order.transition(order, :register)
      {:ok, granted} = Order.transition(registered, :grant)

      assert {:ok, shipped} = Order.transition(granted, :ship)
      assert shipped.state == :shipped
    end

    test "can transition from :granted to :cancelled" do
      order = Order.new("order_1", %{"prod_1" => 2})
      {:ok, registered} = Order.transition(order, :register)
      {:ok, granted} = Order.transition(registered, :grant)

      assert {:ok, cancelled} = Order.transition(granted, :cancel)
      assert cancelled.state == :cancelled
    end

    test "cannot transition from :shipped to :cancelled" do
      order = Order.new("order_1", %{"prod_1" => 2})
      {:ok, registered} = Order.transition(order, :register)
      {:ok, granted} = Order.transition(registered, :grant)
      {:ok, shipped} = Order.transition(granted, :ship)

      assert {:error, :invalid_transition} = Order.transition(shipped, :cancel)
    end
  end
end
