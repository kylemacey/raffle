class PosProductsController < ApplicationController
  before_action :set_pos_product, only: %i[show edit update destroy]

  def index
    @pos_products = PosProduct.all
  end

  def show
  end

  def new
    @pos_product = PosProduct.new
  end

  def create
    @pos_product = PosProduct.new(pos_product_params)
    if @pos_product.save
      redirect_to @pos_product, notice: 'POS Product was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @pos_product.update(pos_product_params)
      redirect_to @pos_product, notice: 'POS Product was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pos_product.destroy
    redirect_to pos_products_url, notice: 'POS Product was successfully destroyed.'
  end

  def reorder
    product_to_move = PosProduct.find(params[:id])
    new_priority = params[:priority].to_i

    # Get all products except the one being moved
    other_products = PosProduct.where.not(id: product_to_move.id).order(:priority)

    # Create an array of all products in their new order
    all_products = other_products.to_a
    all_products.insert(new_priority, product_to_move)

    # Re-assign priority based on the new order
    PosProduct.transaction do
      all_products.each_with_index do |product, index|
        product.update_column(:priority, index)
      end
    end

    head :ok
  end

  def configuration_fields
    product_type = params[:product_type]

    if product_type.present?
      processor_class = PosProducts::Factory.processor_for(product_type)
      if processor_class
        schema = processor_class.configuration_schema
        render partial: 'configuration_fields', locals: { schema: schema }
      else
        render partial: 'configuration_fields', locals: { schema: [] }
      end
    else
      render partial: 'configuration_fields', locals: { schema: [] }
    end
  end

  private
    def set_pos_product
      @pos_product = PosProduct.find(params[:id])
    end

    def pos_product_params
      params.require(:pos_product).permit(:name, :formatted_price, :stripe_product_id, :stripe_price_id, :product_type, :active, :description, configuration: {})
    end
end
