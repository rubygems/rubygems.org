module OauthHelpers
  def stub_github_info_request(info_data)
    stub_request(:post, "https://api.github.com/graphql")
      .with(body: { query: GitHubOAuthable::INFO_QUERY, variables: { organization_name: "rubygems" } }.to_json)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: JSON.generate(data: info_data)
      )
  end
end
