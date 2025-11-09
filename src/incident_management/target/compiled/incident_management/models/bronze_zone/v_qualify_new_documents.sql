

select
   *,
    case 
        when contains(relative_path, 'qa') then 'question'
        when contains(relative_path, 'full') then 'full'
        else 'slack'
    end as doc_type,
    split_part(relative_path, '.', 2) as extension
from incident_management.bronze_zone.documents_stream
WHERE relative_path is not null
and array_contains(extension::VARIANT, ['pdf', 'docx', 'doc', 'txt', 'text', 'html', 'md', 'pptx', 'ppt', 'png', 'eml', 'jpg', 'jpeg', 'gif', 'bmp', 'tiff', 'tif', 'webp', 'htm'] )
and size > 0