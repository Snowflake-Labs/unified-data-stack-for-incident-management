

select
   *,
    case 
        when contains(relative_path, 'qa') then 'question'
        when contains(relative_path, 'full') then 'full'
        else 'full'
    end as analysis_type
from incident_management.bronze_zone.documents_stream
WHERE relative_path is not null
and contains(relative_path, 'pdf|docx|doc|txt|text|html|md|pptx|ppt|png|eml|jpg|jpeg|gif|bmp|tiff|tif|webp|htm')
and size > 0