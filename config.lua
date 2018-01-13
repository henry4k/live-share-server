return
{
    host = '0.0.0.0',
    port = 12345,
    static_content = 'static',
    upload_directory = 'uploads',
    thumbnail =
    {
        directory = 'thumbnails',
        size = 160,
        image_type = 'jpeg',
        vips_format_options = 'optimize_coding,strip,interlace',
        vipsthumbnail_extra_args = {'--smartcrop', 'centre'},
        ffmpeg_extra_args = {}
    },
    database = 'database.db'
}
