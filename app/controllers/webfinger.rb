# webfinger endpoint for Sinatra

get '/.well-known/webfinger' do
  halt 400 unless (resource = params[:resource]).present?
  halt 400 unless (uri = URI.parse(resource) rescue nil)
  halt 404 unless uri.scheme == "acct" # acct only
  halt 500 unless config['webfinger'] and config['webfinger'].any?

  no_scheme = resource.sub /^acct:/, ''
  account = config['webfinger'].find {|acct| acct['acct'] == no_scheme}
  halt 404 unless account

  response = {
    subject: resource,
    properties: account['properties'],
    links: [] # fill in next
  }
  account['links'].each do |rel, href|
    response[:links] << {rel: rel, href: href}
  end

  headers['Content-Type'] = 'application/jrd+json'
  headers['Access-Control-Allow-Origin'] = "*"

  response.to_json
end