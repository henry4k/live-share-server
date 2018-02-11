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
        vips_format_options = {optimize_coding=true,
                               strip=true,
                               interlace=true},
        ffmpeg_extra_args = {}
    },
    password =
    {
        salt_length = 32,
        argon2_options = {t_cost = 3,
                          m_cost = 4096,
                          parallelism = 2,
                          hash_len = 32,
                          variant = 'argon2_id'}
    },
    database = 'database.db'
}
