pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "mcaptcha"
            token_path = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        }
    }
    sink "file" {
        config = {
            path = "/home/vault/.vault-token"
        }
    }
}

template {
  destination = "/secrets/mcaptcha-env"
  contents = <<EOT
export MCAPTCHA_debug=false
export MCAPTCHA_commercial=false
export MCAPTCHA_source_code="https://github.com/opentelekomcloud-infra/mcaptcha"
export MCAPTCHA_allow_registration=false
export MCAPTCHA_allow_demo=false
export MCAPTCHA_database_POOL=4
export MCAPTCHA_redis_POOL=4
export PORT=7001
export MCAPTCHA_server_DOMAIN=mcaptcha.otc-service.com
export MCAPTCHA_server_IP=0.0.0.0
export MCAPTCHA_captcha_GC=30
export MCAPTCHA_captcha_RUNNERS=4
export MCAPTCHA_captcha_QUEUE_LENGTH=2000
export MCAPTCHA_captcha_ENABLE_STATS=true
export MCAPTCHA_captcha_DEFAULT_DIFFICULTY_STRATEGY_avg_traffic_difficulty=8000000
export MCAPTCHA_captcha_DEFAULT_DIFFICULTY_STRATEGY_broke_my_site_traffic_difficulty=10000000
export MCAPTCHA_captcha_DEFAULT_DIFFICULTY_STRATEGY_peak_sustainable_traffic_difficulty=15000000
export MCAPTCHA_captcha_DEFAULT_DIFFICULTY_STRATEGY_duration=30
export MCAPTCHA_captcha_DEFAULT_DIFFICULTY_STRATEGY_avg_traffic_time=8
export MCAPTCHA_captcha_DEFAULT_DIFFICULTY_STRATEGY_peak_sustainable_traffic_time=10
export MCAPTCHA_captcha_DEFAULT_DIFFICULTY_STRATEGY_broke_my_site_traffic_time=15

{{ with secret "secret/data/mcaptcha" -}}
export DATABASE_URL="{{ .Data.data.database_url }}"
export MCAPTCHA_redis_URL="{{ .Data.data.redis_url }}"
export MCAPTCHA_server_COOKIE_SECRET="{{ .Data.data.server_cookie_secret }}"
export MCAPTCHA_captcha_SALT="{{ .Data.data.captcha_salt }}"
# SMTP (Uncomment and replace with real secrets if SMTP is used)
# export MCAPTCHA_smtp_FROM="{{ .Data.data.smtp_from }}"
# export MCAPTCHA_smtp_REPLY="{{ .Data.data.smtp_reply }}"
# export MCAPTCHA_smtp_URL="{{ .Data.data.smtp_url }}"
# export MCAPTCHA_smtp_USERNAME="{{ .Data.data.smtp_username }}"
# export MCAPTCHA_smtp_PASSWORD="{{ .Data.data.smtp_password }}"
# export MCAPTCHA_smtp_PORT={{ .Data.data.smtp_port }}
{{- end }}
EOT
  perms = "0664"
}
