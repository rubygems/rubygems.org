class <%= class_name %>Controller < ApplicationController
<% resource       = file_name.singularize -%>
<% resources      = file_name.pluralize -%>
<% resource_class = class_name.singularize -%>

<% if actions.include?("index") -%>
  def index
  end

<% end -%>
<% if actions.include?("new") -%>
  def new
    @<%= resource %> = <%= resource_class %>.new
  end

<% end -%>
<% if actions.include?("create") -%>
  def create
    @<%= resource %> = <%= resource_class %>.new(params[:<%= resource %>])
    @<%= resource %>.save
    flash[:success] = '<%= resource_class %> created.'
    redirect_to <%= resources %>_path
  end

<% end -%>
<% if actions.include?("show") -%>
  def show
    @<%= resource %> = <%= resource_class %>.find(params[:id])
  end

<% end -%>
<% if actions.include?("edit") -%>
  def edit
    @<%= resource %> = <%= resource_class %>.find(params[:id])
  end

<% end -%>
<% if actions.include?("update") -%>
  def update
    @<%= resource %> = <%= resource_class %>.find(params[:id])
    @<%= resource %>.update_attributes(params[:<%= resource %>])
    flash[:success] = '<%= resource_class %> updated.'
    redirect_to <%= resources %>_path
  end

<% end -%>
<% if actions.include?("destroy") -%>
  def destroy
    @<%= resource %> = <%= resource_class %>.find(params[:id])
    @<%= resource %>.destroy
    flash[:success] = '<%= resource_class %> deleted.'
    redirect_to <%= resources %>_path
  end

<% end -%>
end
