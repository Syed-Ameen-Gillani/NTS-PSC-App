-- Keep the recorded type consistent with the immutable Storage path.
alter table public.assignment_submission_attachments
add constraint assignment_attachment_extension_type check (
  (mime_type = case lower(split_part(object_path, '.', 2))
    when 'pdf' then 'application/pdf'
    when 'doc' then 'application/msword'
    when 'docx' then 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    when 'ppt' then 'application/vnd.ms-powerpoint'
    when 'pptx' then 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
    when 'xls' then 'application/vnd.ms-excel'
    when 'xlsx' then 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    when 'txt' then 'text/plain'
    when 'jpg' then 'image/jpeg'
    when 'jpeg' then 'image/jpeg'
    when 'png' then 'image/png'
    when 'mp4' then 'video/mp4'
    when 'mov' then 'video/quicktime'
    else null
  end) is true
);
