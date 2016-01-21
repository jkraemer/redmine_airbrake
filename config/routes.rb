# API v2
post 'notifier_api/:version/notices', to: 'airbrake_notices#create'

# API v3
post 'api/:version/projects/:project/notices', to: 'airbrake_notices#create'

