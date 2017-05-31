class TagsController < ApplicationController
  before_action :logged_in_user, except: [:show]
  before_action :user_can_edit, except: [:show]
  before_action :get_simple_params, only: [:new, :edit]
  before_action :get_params, except: [:index, :show, :edit, :new, 
    :connect, :disconnect]
  before_action :get_tag, except: [:index]
  before_action :get_verticals
  before_action :get_redirect_path

  def show
  end

  def new
  end

  def edit
  end

  def index
    @tags = Tag.all.sort_by{|e| e.text}
  end

  ## This is a little different from other resource controllers' create
  ## method; here, we split the tag text by comma and treat each chunk as
  ## it's own tag. Text that already exists as a tag isn't recreated, but is
  ## linked to the vertical requesting the creation.
  def create
    begin
        throw Exception("No vertical specified!") if @vertical.nil?
        @params[:text].split(/\s*,\s*/).each do |tag_text|
          tag = Tag.find_by(text: tag_text) || Tag.create!(text: tag_text)
          @vertical.tags << tag
          @vertical.save!
        end

      respond_with_success @redirect_path
    rescue
      respond_with_error("The web resource could not be created; check if an "+
        "existing resource has the same URL and description.", @redirect_path)
    end
  end

  def update
    begin
      @tag.update_attributes! @params
      respond_with_success @redirect_path
    rescue
      respond_with_error "The web resource could not be updated.", 
        @redirect_path
    end
  end

  def destroy
  end

  def connect
    begin
      @vertical.tags << @tag
      @vertical.save!
      respond_with_success @redirect_path
    rescue => e
      respond_with_error "The web resource could not be associated with the "+
        "requested vertical.", @redirect_path
    end
  end

  def disconnect
    begin
      if @vertical.tags.exists?(id: @tag.id)
        @tag.destroy_if_isolated(1)
        @vertical.tags.delete(@tag)
        @vertical.save! 
      end
      respond_with_success @redirect_path
    rescue => e
      respond_with_error "The web resource could not be disassociated with the"+
        " requested vertical.", @redirect_path
    end
  end

  private

    def get_simple_params
      @params = params.permit(:software_id, :redirect_path, :id)
    end


    ## Extracts the allowed parameters into a global named @data.
    def get_params
      begin
        @params = params.require(:tag).permit(:text)
      rescue => e
        respond_with_error "Required parameters not supplied."
      end
    end

    def get_tag
      if params.key? :id
        @tag = Tag.find(params[:id])
      else
        @tag = Tag.new
      end
    end

    ## Gets the associated software or other vertical.
    def get_verticals
      begin
        @vertical = nil
        @software = nil

        if params.key? :software_id
          @software = Software.find(params[:software_id]) 
          @vertical = @software
        end

      rescue
        error = "Invalid vertical id given."

      end
    end


    ## Gets the back path (where to go on submit or cancel).
    def get_redirect_path
      if params.key? :redirect_path
        @redirect_path = params[:redirect_path]
      elsif not @software.nil?
        @redirect_path = software_path(@software.id)
      else
        @redirect_path = root_path
      end
    end
end