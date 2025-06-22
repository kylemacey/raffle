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
