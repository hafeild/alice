require "test_helper"

class WebResourcesControllerTest < ActionController::TestCase

  ##############################################################################
  ## Testing create

  test "should break when creating a web resource without being logging in" do
    assert_no_difference "WebResource.count", "WebResource created" do
      post :create, params: { web_resource: { 
        url: "x", description: "x" } }
      assert_redirected_to login_path, @response.body
    end
  end

  test "should create web_resource and link to software page" do
    log_in_as users(:foo)
    software = software(:one)
    assert_difference "WebResource.count", 1, "Web resource not created" do
      post :create, params: { software_id: software.id, web_resource: { 
        url: "x", description: "x" } }
      assert_redirected_to software_path(software), @response.body
    end
  end

  test "should break when creating a web resource with no url or description" do
    log_in_as users(:foo)
    software = software(:one)
    assert_no_difference "WebResource.count", "WebResource created" do
      post :create, params: { software_id: software.id, 
        web_resource: { url: "", description: "" } }
      assert_redirected_to software_path(software), @response.body

      post :create, params: { software_id: software.id,
        web_resource: { url: "xyz", description: "" } }
      assert_redirected_to software_path(software), @response.body

      post :create, params: { software_id: software.id,
        web_resource: { url: "", description: "xyz" } }
      assert_redirected_to software_path(software), @response.body
    end
  end

  test "should break when creating a web resource with a non-unique url" do
    log_in_as users(:foo)
    software = software(:one)
    web_resource = web_resources(:one)
    assert_no_difference "WebResource.count", "Web resource created" do
      post :create, params: { software_id: software.id,
        web_resource: { url: web_resource.url, description: "xyz" } }
      assert_redirected_to software_path(software), @response.body
    end
  end

  test "should break when creating a web resource with a long url" do
    log_in_as users(:foo)
    software = software(:one)
    assert_no_difference "WebResource.count", "Web resource created" do
      post :create, params: { software_id: software.id,
        web_resource: { url: "x"*201, description: "xyz" } }
      assert_redirected_to software_path(software), @response.body
    end
  end

  ##############################################################################


  ##############################################################################
  ## Testing making a connection between verticals to existing web_resources.

  test "should link web_resource to software page" do
    log_in_as users(:foo)
    software = software(:one)
    web_resource = web_resources(:one)
    assert_difference "software.web_resources.size", 1, "Web resource not linked" do
      post :connect, params: { software_id: software.id, id: web_resource.id }
      assert_redirected_to software_path(software), @response.body
      software.reload
    end
  end

  ##############################################################################


  ##############################################################################
  ## Testing removing a connection between verticals and web_resources.

  test "should unlink web_resource to software page" do
    log_in_as users(:foo)
    software = software(:two)
    web_resource = web_resources(:one)
    assert_difference "software.web_resources.size", -1, "Web resource not unlinked" do
      delete :disconnect, params: { software_id: software.id, id: web_resource.id }
      assert_redirected_to software_path(software), @response.body
      assert WebResource.find_by(id: web_resource.id).nil?
      software.reload
    end
  end

  ##############################################################################

  ##############################################################################
  ## Testing updating an web_resource.

  test "should update the web_resource of redirect to a software page" do
    log_in_as users(:foo)
    software = software(:two)
    web_resource = web_resources(:one)
    patch :update, params: { software_id: software.id, id: web_resource.id,
      web_resource: { url: "A better web_resource!" } }
    assert_redirected_to software_path(software), @response.body
    web_resource.reload
    assert web_resource.url == "A better web_resource!"
  end

  ##############################################################################



end