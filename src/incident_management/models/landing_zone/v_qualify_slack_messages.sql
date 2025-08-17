select 
    sm.hasfile,
    sm.hasfiles,
    sm.type,
    sm.subtype,
    sm.team,
    sm.channel,
    sm.user,
    sm.username,
    sm.text,
    sm.ts,
    randstr(7, random()) as slack_message_id,
    
    -- Attachment metadata
    dm.file_name, 
    dm.file_mimetype, 
    dm.file_size, 
    dm.staged_file_path,
    case 
        when hasfiles then to_file('{{ var("docs_stage_path") }}', dm.staged_file_path)
        else null
    end as attachment_file,
    case 
        -- When there is an attachment file and it is an image, use the image to extract the incident code
        when attachment_file is not null and fl_is_image(attachment_file) then 
        ai_complete('claude-3-5-sonnet',
            prompt(
            $$
            Extract incident codes from image {0} and/or Slack text {1}. 
            Look for alphanumeric codes preceded by the keyword 'incident' (case-insensitive). 
            Examples: INC-12345, incident_001, INCIDENT-ABC123.
            Respond only in JSON format with a single key called 'incident_code'.
            Do not add any explanation in the response.
            $$, 
            attachment_file, 
            text
            )
        )
        -- When there is no attachment file or it is not an image, use the text to extract the incident code
        else ai_complete('claude-3-5-sonnet',
                prompt(
                $$
                Extract incident codes from Slack text {0}. 
                Look for alphanumeric codes preceded by the keyword 'incident' (case-insensitive). 
                Examples: INC-12345, incident_001, INCIDENT-ABC123.
                Respond only in JSON format with a single key called 'incident_code'.
                Do not add any explanation in the response.
                $$, 
                text
            )
    end as incident_number

from {{ source('landing_zone', 'slack_messages') }} sm
left outer join {{source('landing_zone', 'doc_metadata')}} dm 
on (sm.hasfiles and (sm.channel = dm.channel_id) and (sm.ts = dm.event_ts))
where sm.ts > (select max(sm.ts) from {{ this }})
