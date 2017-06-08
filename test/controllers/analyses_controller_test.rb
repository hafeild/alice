require 'test_helper'

class AnalysesControllerTest < ActionController::TestCase

  ##############################################################################
  ## Testing create

  test "should break when creating a page without being logging in" do
    #log_in_as users(:foo)
    assert_no_difference 'Analysis.count', "Analysis page created" do
      reponse = post :create, params: { analysis: { 
        name: "x", summary: "x", description: "x" } }
      assert_redirected_to login_path, response.body
    end
  end

  test "should create a analysis page as a logged in user" do
    log_in_as users(:foo)
    assert_difference 'Analysis.count', 1, "Analysis page not created" do
      response = post :create, params: { analysis: { 
        name: "x", summary: "x", description: "x" } }
      assert_redirected_to analysis_path(Analysis.last.id), response.body
    end
  end

  test "should break if don't include any of: name, summary, or description" do
    log_in_as users(:foo)

    ## Exclude name.
    assert_no_difference 'Analysis.count', 
        "Excluding name should not have worked" do
      response = post :create, params: { analysis: { 
        summary: "x", description: "x" } }
      assert_redirected_to new_analysis_path, response.body
    end

    ## Exclude summary.
    assert_no_difference 'Analysis.count', 
        "Excluding summary should not have worked" do
      response = post :create, params: { analysis: { 
        name: "x", description: "x" } }
      assert_redirected_to new_analysis_path, response.body
    end

    ## Exclude description.
    assert_no_difference 'Analysis.count', 
        "Excluding description should not have worked" do
      response = post :create, params: { analysis: { 
        name: "x", summary: "x" } }
      assert_redirected_to new_analysis_path, response.body
    end
  end

  ## JSON response errors.

  test "should return must be logged in json error" do
    ## Not logged in.
    @request.env['CONTENT_TYPE'] = 'application/json'
    post :create, format: :json, params: { analysis: { 
        name: "x", summary: "x", description: "x" } }
    result = JSON.parse(@response.body)
    assert_not result['success']
    assert result['error'] = "You must be logged in to modify content."
  end

  test "should return success json on basic create" do
    ## Logged in, successful create.
    @request.env['CONTENT_TYPE'] = 'application/json'
    log_in_as users(:foo)
    post :create, format: :json, params: { analysis: { 
      name: "x", summary: "x", description: "x" } }
    result = JSON.parse(@response.body)
    assert result['success']
    assert result['redirect'] == analysis_path(Analysis.last.id)
  end

  test "should return missing params json error message" do
    ## Missing required field.
    @request.env['CONTENT_TYPE'] = 'application/json'
    log_in_as users(:foo)
    post :create, format: :json, params: { analysis: { 
        name: "x", summary: ""   } }
    result = JSON.parse(@response.body)
    assert_not result['success']
    assert result['error']=="You must provide a name, summary, and description."
  end

  test "should return required params not supplied json error" do
    ## No analysis parameter.
    @request.env['CONTENT_TYPE'] = 'application/json'
    log_in_as users(:foo)
    post :create, format: :json, params: {}
    result = JSON.parse(@response.body)
    assert_not result['success']
    assert result['error'] == "Required parameters not supplied."
  end

  test "should return saving analysis json error" do
    ## No analysis parameter.
    @request.env['CONTENT_TYPE'] = 'application/json'
    log_in_as users(:foo)
    post :create, format: :json, params: {analysis: { 
      name: analyses(:one).name, summary: "x", description: "x" }}
    result = JSON.parse(@response.body)
    assert_not result['success']
    assert result['error'] == "There was an error saving the analysis entry."
  end

  ## End create tests
  ##############################################################################


  ##############################################################################
  ## Update tests.

  test "shouldn't update analysis entry when not logged in" do 
    analysis = analyses(:one)
    analysis_name = "MY ANALYSIS"
    analysis_description = "YABBA DABBA DOO"
    analysis_summary = "A ANALYSIS SUMMARY"

    patch :update, params: { id:analysis.id,
      analysis: {name: analysis_name, summary: analysis_summary,
        description: analysis_description}}

    analysis.reload
    assert_not analysis.name == analysis_name
    assert_not analysis.summary == analysis_summary
    assert_not analysis.description == analysis_description
  end

  test "should update analysis entry when logged in" do 
    log_in_as users(:foo)
    analysis = analyses(:one)
    analysis_name = "MY ANALYSIS"
    analysis_description = "YABBA DABBA DOO"
    analysis_summary = "A ANALYSIS SUMMARY"

    patch :update, params: { id:analysis.id,
      analysis: {name: analysis_name, summary: analysis_summary,
        description: analysis_description}}

    analysis.reload
    assert analysis.name == analysis_name
    assert analysis.summary == analysis_summary
    assert analysis.description == analysis_description
  end

  test "shouldn't update analysis entry with a non-unique name" do
    log_in_as users(:foo)
    analysis = analyses(:one)
    analysis_name = analyses(:two).name
    analysis_description = "YABBA DABBA DOO"
    analysis_summary = "A ANALYSIS SUMMARY"

    patch :update, params: { id:analysis.id,
      analysis: {name: analysis_name, summary: analysis_summary,
        description: analysis_description}}

    analysis.reload
    assert_not analysis.name == analysis_name, "#{analysis.name} | #{analysis_name}"
    assert_not analysis.summary == analysis_summary, analysis.summary
    assert_not analysis.description == analysis_description, analysis.description
  end


  ## JSON response on update tests.

  test "should return unknown analysis json error on update" do
    ## No analysis parameter.
    @request.env['CONTENT_TYPE'] = 'application/json'
    log_in_as users(:foo)
    patch :update, format: :json, params: {id: 0, analysis: { 
      name: "x", summary: "x", description: "x" }}
    result = JSON.parse(@response.body)
    assert_not result['success']
    assert result['error'] == "No analysis with the specified id exists."
  end

  test "should return success json message with redirect to analysis "+
      " page on update" do
    ## No analysis parameter.
    @request.env['CONTENT_TYPE'] = 'application/json'
    log_in_as users(:foo)
    analysis = analyses(:one)
    analysis_name = "MY ANALYSIS"
    analysis_description = "YABBA DABBA DOO"
    analysis_summary = "A ANALYSIS SUMMARY"

    patch :update, format: :json, params: { id:analysis.id,
      analysis: {name: analysis_name, summary: analysis_summary,
        description: analysis_description}}

    result = JSON.parse(@response.body)
    assert result['success']
    assert result['redirect'] == analysis_path(analysis.id)
  end

  test "should return error updating analysis json message on update" do
    ## No analysis parameter.
    @request.env['CONTENT_TYPE'] = 'application/json'
    log_in_as users(:foo)
    analysis = analyses(:one)
    analysis_name = analyses(:two).name
    analysis_description = "YABBA DABBA DOO"
    analysis_summary = "A ANALYSIS SUMMARY"

    patch :update, format: :json, params: { id:analysis.id,
      analysis: {name: analysis_name, summary: analysis_summary,
        description: analysis_description}}

    result = JSON.parse(@response.body)
    assert_not result['success']
    assert result['error'] == "There was an error updating the analysis entry."
  end

  ## End update tests.
  ##############################################################################

  ##############################################################################
  ## Destroy tests.

  test "should destroy a analysis page and any resources unique to it" do 
    log_in_as users(:foo)
    analysis = analyses(:two)
    tag = analysis.tags.first
    example = analysis.examples.first
    web_resource = analysis.web_resources.first

    assert_not example.nil?, analysis.examples.size

    assert_difference 'Analysis.count', -1, "Analysis page not removed" do
    assert_difference 'WebResource.count', -1, "Web resource not removed" do
    assert_difference 'Example.count', -1, "Example not removed" do
    assert_difference 'Tag.count', -1, "Tag not removed" do

      delete :destroy, params: {id: analysis.id}

      assert Analysis.find_by(id: analysis.id).nil?, "Analysis not removed"
      assert Tag.find_by(id: tag.id).nil?, "Tag not removed"
      assert Example.find_by(id: example.id).nil?, "Example not removed"
      assert WebResource.find_by(id: web_resource.id).nil?, 
        "Web resource not removed"

    end
    end
    end
    end

  end

  ## End destroy tests.
  ##############################################################################

end