require "test_helper"

class PosProducts::FactoryTest < ActiveSupport::TestCase
  test "available_types returns all product types" do
    expected_types = ["raffle", "subscription"]
    assert_equal expected_types, PosProducts::Factory.available_types
  end

  test "processor_for returns correct class for raffle" do
    processor_class = PosProducts::Factory.processor_for("raffle")
    assert_equal PosProducts::Raffle, processor_class
  end

  test "processor_for returns correct class for subscription" do
    processor_class = PosProducts::Factory.processor_for("subscription")
    assert_equal PosProducts::Subscription, processor_class
  end

  test "processor_for returns nil for unknown product type" do
    processor_class = PosProducts::Factory.processor_for("unknown")
    assert_nil processor_class
  end

  test "create_processor creates processor instance for valid product type" do
    pos_product = PosProduct.new(product_type: "raffle")
    processor = PosProducts::Factory.create_processor(pos_product)

    assert_instance_of PosProducts::Raffle, processor
    assert_equal pos_product, processor.pos_product
  end

  test "create_processor returns nil for product type without processor" do
    pos_product = PosProduct.new(product_type: "unknown")
    processor = PosProducts::Factory.create_processor(pos_product)

    assert_nil processor
  end

  test "has_processor? returns true for product types with processors" do
    assert PosProducts::Factory.has_processor?("raffle")
    assert PosProducts::Factory.has_processor?("subscription")
  end

  test "has_processor? returns false for product types without processors" do
    refute PosProducts::Factory.has_processor?("unknown")
    refute PosProducts::Factory.has_processor?("merchandise")
  end

  test "human_readable_types returns correct mapping" do
    expected = {
      "raffle" => "Raffle Tickets",
      "subscription" => "Subscription"
    }
    assert_equal expected, PosProducts::Factory.human_readable_types
  end
end