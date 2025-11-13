Gem::Specification.new do |spec|
  spec.name          = "quickbooks_mcp"
  spec.version       = "1.0.0"
  spec.authors       = ["QuickBooks MCP"]
  spec.email         = ["andrei@sourcelabs.io"]

  spec.summary       = "QuickBooks MCP Server"
  spec.description   = "Model Context Protocol server for QuickBooks Online integration"
  spec.homepage      = "https://github.com/andreibondarev/ruby-quickbooks-mcp-server"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency "mcp"
  spec.add_dependency "quickbooks-ruby", "~> 2.0"
  spec.add_dependency "dotenv", "~> 3.1"
  spec.add_dependency "oauth2", "~> 1.4"
  spec.add_dependency "puma", "~> 6.5"
  spec.add_dependency "rackup", "~> 2.2"
end
