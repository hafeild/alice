class SearchController < ApplicationController  
  before_action :set_search_indicator, only: [:show]
  before_action :get_vertical_map, only: [:show]
  before_action :get_redirect_path
  
  def show    
    begin
      start_time = Time.now
    
      @search_params = params.permit(:vertical, :q, :cursor, :full_json,
        :advanced, :nq, :sq, :dq, :tq, :eq, :wrq, :aq, :lcq, :all, :sr)
      @vertical = @search_params.require(:vertical)
      
      # if @vertical == 'users'
      #   match_users
      #   return
      # end

      ## Check that vertical is valid:
      throw Exception.new('Invalid vertical.') unless valid_vertical(@vertical)
      
      
      ## Other options.
      cursor = get_with_default(@search_params, :cursor, '*')
      if cursor == '*'
        @starting_rank = 1
      else
        @starting_rank = get_with_default(@search_params, :sr, '1').to_i
      end
      
      full_json = get_with_default(@search_params, :full_json, '') == 'true'
      @advanced = get_with_default(@search_params, :advanced, '') == 'true'
      extract_advanced_query()
      
      
      ## Advanced queries.
      if @advanced
        @query = get_with_default(@search_params, :q, "").downcase.chomp
        
        if @query.size == 0 && !@advanced_query_fields.any?{|k,v| v.size > 0}
          throw Exception.new('At least one search field must be filled.')
        end
        
        field_queries = Proc.new do |dsl|
          @advanced_query_fields.each do |field, value|
            unless value == ''
              dsl.keywords value, fields: field
            end
          end
        end
        
        
        query_body = Proc.new do |dsl|
          dsl.order_by :score, :desc
          #dsl.paginate page: 1, per_page: 10
          dsl.paginate cursor: cursor, per_page: 10
          ## General query.
          unless @query == ''
            dsl.keywords @query do
              boost_fields name: 20.0, summary: 15.0, description: 10.0,
                tags: 1.0, web_resources: 0.75, examples: 0.5
            end
          end
          
          if @is_conjunction
            dsl.all do
              field_queries.call(dsl)
            end
          else
            dsl.any do
              field_queries.call(dsl)
            end
          end

          dsl.adjust_solr_params do |params|
            params["q.op"] = "OR"
          end
        end

      ## Simple keyword queries.
      else
        
        @query = @search_params.require(:q).to_s.downcase
        query_body = Proc.new do |dsl|
          dsl.order_by :score, :desc
          #dsl.paginate page: 1, per_page: 10
          dsl.paginate cursor: cursor, per_page: 10
          # dsl.keywords @query do
          dsl.fulltext @query do
            boost_fields name: 20.0, summary: 15.0, description: 10.0,
              tags: 1.0, web_resources: 0.75, examples: 0.5
          end
          dsl.adjust_solr_params do |params|
            params["q.op"] = "OR"
          end
        end
      end
      
      if @vertical == 'all'
        @search = Sunspot.search( AssignmentGroup, Analysis, Software, Dataset, 
          Example, &query_body )
      else
        @search = Sunspot.search @vertical_map[@vertical], &query_body
      end
      
      
      
      end_time = Time.now
      
      @query_seconds = (end_time - start_time)/1000.0
      
      respond_to do |format|
        format.json do 
          render json: {
            success: true, 
            last_page: @search.results.last_page?,
            current_cursor: @search.results.current_cursor,
            next_page_cursor: @search.results.next_page_cursor,
            next_rank: @starting_rank + @search.hits.size,
            result_set_html: render_to_string(
                partial: 'search/result_set.html.erb', 
                locals: {search: @search}, formats: [:html])
          }
        end
        format.html { render 'show' }
      end
    rescue => e 
      # render text: e
      # puts "#{e.message} #{e.backtrace.join("\n")}"

      
      respond_with_error "There was an error while executing your search: #{e}.", 
        @redirect_path
    end
  end

  def match_users
    begin
      start_time = Time.now

      @search_params = params.permit(:q, :format)
      #@query = params.require(:query).to_s.downcase
      @query = get_with_default(@search_params, :q, "")

      query_body = Proc.new do |dsl|
        dsl.order_by :score, :desc
        dsl.paginate page: 1, per_page: 10
        # dsl.paginate cursor: cursor, per_page: 10
        dsl.fulltext @query do
          fields :username, :email, :last_name, :first_name
        end
      end

      @search = Sunspot.search(User, &query_body)

      end_time = Time.now
      @query_seconds = (end_time - start_time)/1000.0
      render 'show_matched_users'
    rescue => e
      # puts "#{e.message} #{e.backtrace.join("\n")}"
      respond_with_error "There was an error while executing your search: #{e}.",
        @redirect_path
    end

  end

  
  private  
    def set_search_indicator
      @is_search_page = true
    end
  
    def get_vertical_map
      @vertical_map = {
        'all' => nil,
        'assignments' => AssignmentGroup,
        'examples' => Example,
        'analyses' => Analysis,
        'datasets' => Dataset,
        'software' => Software
      }
    end
  
  
    def valid_vertical(vertical)
      return @vertical_map.key? vertical
    end
  
  
    def extract_advanced_query()
      @advanced_query_fields = {
        name: get_with_default(@search_params, :nq, ''),
        description: get_with_default(@search_params, :dq, ''),
        summary: get_with_default(@search_params, :sq, ''),
        tags: get_with_default(@search_params, :tq, ''),
        examples: get_with_default(@search_params, :eq, ''),
        web_resources: get_with_default(@search_params, :wrq, ''),
        authors: get_with_default(@search_params, :aq, ''),
        # instructor: get_with_default(@search_params, :iq, ''),
        # assignment_results: get_with_default(@search_params, :arq, ''),
        learning_curve: get_with_default(@search_params, :lcq, '')
      }
      @advanced_query_fields.each{|k,v| 
        @advanced_query_fields[k] = v.chomp.downcase}
      @is_conjunction = get_with_default(@search_params, :all, 'false') == 'true'
      
    end
end
