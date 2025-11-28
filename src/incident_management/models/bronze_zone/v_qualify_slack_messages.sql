{{
    config(
        materialized='view'
        , description='View to qualify Slack messages that could be related to incidents by extracting the incident number from the message'
        , tags=['daily']
    )
}}

-- Only propagate messages from known reporters (users in channel)
with slack_messages_from_known_reporters as (
    select sm.*, r.id as reporter_id
    from {{ source('bronze_zone', 'slack_messages') }} sm
    inner join {{ source('bronze_zone', 'users') }} r on sm.username = split(r.email, '@')[0]
    where sm.clientmsgid is not null
    and to_date(sm.ingestts) >= to_date(current_timestamp())
)

-- Messages with attachments (with join to doc_metadata)
select 
    true as hasfiles,
    sm.type,
    sm.subtype,
    sm.team,
    sm.channel,
    sm.user,
    sm.username,
    sm.reporter_id,
    sm.text,
    sm.ts,
    sm.clientmsgid as slack_message_id,
    
    -- Attachment metadata from doc_metadata
    dm.file_id,
    dm.file_name, 
    dm.file_mimetype, 
    dm.file_size, 
    dm.staged_file_path,
    to_file('{{ var("docs_stage_path") }}', dm.staged_file_path) as attachment_file,
    case 
        -- When there is an attachment file and it is an image, use the image to extract the incident code
        -- TODO: Add structured response
        when dm.staged_file_path is not null and fl_is_image(to_file('{{ var("docs_stage_path") }}', dm.staged_file_path)) then 
        ai_complete('claude-3-5-sonnet',
            prompt(
            $$
            Find the incident number that may be present either in the image {0} or in the text {1}. 
            Use the one in the image if found.Look for alphanumeric codes preceded by the keyword 'incident' (case-insensitive). 
            Examples: INC-12345, incident_001, INC-2025-001.
            Respond only in JSON format with a single key called 'incident_code'.
            Do not add any explanation in the response.
            $$, 
            attachment_file,
            text
            )
        )
        else null
    end as incident_number

from slack_messages_from_known_reporters sm
inner join {{source('bronze_zone', 'doc_metadata')}} dm 
on (sm.hasfiles and (sm.channel = dm.channel_id) and (sm.ts = dm.event_ts))

UNION ALL

-- Messages without attachments (no join to doc_metadata)
select 
    false as hasfiles,
    sm.type,
    sm.subtype,
    sm.team,
    sm.channel,
    sm.user,
    sm.username,
    sm.reporter_id,
    sm.text,
    sm.ts,
    sm.clientmsgid as slack_message_id,
    
    -- No attachment metadata for messages without files
    null as file_id,
    null as file_name, 
    null as file_mimetype, 
    null as file_size, 
    null as staged_file_path,
    null as attachment_file,
    case 
        -- Only use text to extract the incident code since there are no attachments
        -- TODO: Add structured response
        when sm.text is not null then ai_complete('claude-3-5-sonnet',
                prompt(
                $$
                Extract incident codes from Slack text {0}. 
                Look for alphanumeric codes preceded by the keyword 'incident' (case-insensitive). 
                Examples: INC-12345, incident_001, INC-2025-001.
                Respond only in JSON format with a single key called 'incident_code'.
                Do not add any explanation in the response.
                $$, 
                text
            )
        )
        else null
    end as incident_number

from slack_messages_from_known_reporters sm
where not sm.hasfiles or sm.hasfiles is null
