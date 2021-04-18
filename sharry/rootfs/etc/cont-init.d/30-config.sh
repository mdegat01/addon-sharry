#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Add-on: Sharry
# This validates config, creates the database and sets up app files/folders
# ==============================================================================
readonly DATABASE=sharry
declare host
declare port
declare username
declare password
declare property
declare log_level

# --- ADDITIONAL VALIDATION ---
for var in $(bashio::config 'conf_overrides|keys'); do
    property=$(bashio::config "conf_overrides[${var}].property")
    if [[ ${property} =~ ^sharry[.]restserver[.]backend[.]auth[.]command ]]; then
        bashio::log.fatal
        bashio::log.fatal "You're config attempts to override settings in the command"
        bashio::log.fatal "auth module. This is not allowed as it would break the ability"
        bashio::log.fatal "of this addon to authenticate users with Home Assistant."
        bashio::log.fatal
        bashio::log.fatal "Remove any conf_overrides you have added with a property"
        bashio::log.fatal "matching this pattern and try again:"
        bashio::log.fatal "'sharry.restserver.backend.auth.command.*'"
        bashio::log.fatal
        bashio::exit.nok
    fi
done

# --- SET UP DATABASE ---
bashio::log.debug 'Setting up database.'
# Use user-provided remote db
if ! bashio::config.is_empty 'remote_db_host'; then
    bashio::config.require 'remote_db_type' "'remote_db_host' is specified"
    bashio::config.require 'remote_db_database' "'remote_db_host' is specified"
    bashio::config.require 'remote_db_username' "'remote_db_host' is specified"
    bashio::config.require 'remote_db_password' "'remote_db_host' is specified"
    bashio::config.require 'remote_db_port' "'remote_db_host' is specified"

    host=$(bashio::config 'remote_db_host')
    port=$(bashio::config 'remote_db_port')
    bashio::log.info "Using remote database at ${host}:${port}"

    # Wait until db is available.
    connected=false
    for _ in {1..30}; do
        if nc -w1 "${host}" "${port}" > /dev/null 2>&1; then
            connected=true
            break
        fi
        sleep 1
    done

    if [ $connected = false ]; then
        bashio::log.fatal
        bashio::log.fatal "Cannot connect to remote database at ${host}:${port}!"
        bashio::log.fatal "Exiting after retrying for 30 seconds."
        bashio::log.fatal
        bashio::log.fatal "Please ensure the config is set correctly and"
        bashio::log.fatal "the database is available at the specified host and port."
        bashio::log.fatal
        bashio::exit.nok
    fi

# Use mysql service provided by supervisor
else
    if ! bashio::services.available 'mysql'; then
        bashio::log.fatal
        bashio::log.fatal 'MariaDB addon not available and no alternate database supplied'
        bashio::log.fatal 'Ensure MariaDB addon is available or provide an alternate database'
        bashio::log.fatal
        bashio::exit.nok
    fi

    host=$(bashio::services 'mysql' 'host')
    port=$(bashio::services 'mysql' 'port')
    username=$(bashio::services 'mysql' 'username')
    password=$(bashio::services 'mysql' 'password')

    bashio::log.notice "Sharry is using the Maria DB addon's database"
    bashio::log.notice "Please ensure that addon is included in your backups"
    bashio::log.notice "Uninstalling the Maria DB addon will also remove Sharry's data"

    if bashio::config.true 'reset_database'; then
        bashio::log.warning 'Resetting database...'
        echo "DROP DATABASE IF EXISTS \`${DATABASE}\`;" \
            | mysql -h "${host}" -P "${port}" -u "${username}" -p"${password}"

        # Remove `reset_database` option
        bashio::addon.option 'reset_database'
    fi

    # Create database if it doesn't exist
    echo "CREATE DATABASE IF NOT EXISTS \`${DATABASE}\`;" \
        | mysql -h "${host}" -P "${port}" -u "${username}" -p"${password}"
fi

# --- SET LOG LEVEL ---
# Can't be set with arguments or env variables, search & replace config file
case "$(bashio::config 'log_level')" in \
    trace)      log_level='TRACE';& \
    debug)      log_level='DEBUG' ;; \
    notice)     ;& \
    warning)    log_level='WARN' ;; \
    error)      ;& \
    fatal)      log_level='ERROR' ;; \
    *)          log_level='INFO' ;; \
esac;
bashio::log.info "Sharry log level set to ${log_level}"
sed -i "s#%%LOG_LEVEL%%#${log_level}#g" /etc/sharry/logback.xml
