variable "buckets" {
  type        = map(any)
  description = "Map for S3 buckets"

  default = {
    region = "ap-northeast-2"

    bucket1 = {
      name                = "mytestbucket-20250207-1"
      object_lock_enabled = false
      object_ownership    = "BucketOwnerEnforced" # BucketOwnerPreferred, ObjectWriter
      # acl은 object_ownership이 BubcketOwnerEnforced가 아닐 때만 사용 가능함
      acl                        = "private" # public-read, public-read-write, aws-exec-read, authenticated-read, bucket-owner-read, bucket-owner-full-control, log-delivery-write
      public_access_deny         = true
      enable_bucket_versioning   = true
      enable_kms_encryption      = true
      enable_transfer_accelerate = true

      # access_log enable 할 때 대상 버킷 먼저 생성되어 있는 상태인지 확인
      enable_bucket_access_log = true
      # dest 버킷은 액세스 로깅 활성화 하면 안됨
      dest_bucket_name = "mytestbucket-20250207-2"
      # 아래 변수 false로 되어있으면 대상 버킷의 policy 덮어쓰니까 주의해야함 / true로 되어 있을 땐 규칙 중복에 주의해야함
      dest_bucket_has_policy = false
      dest_object_prefix     = "s3-accesslog/" # 끝에 / 붙여 줘야함
    }
    bucket2 = {
      name                       = "mytestbucket-20250207-2"
      object_lock_enabled        = false
      object_ownership           = "BucketOwnerEnforced" # BucketOwnerPreferred, ObjectWriter
      acl                        = "private"             # public-read, public-read-write, aws-exec-read, authenticated-read, bucket-owner-read, bucket-owner-full-control, log-delivery-write
      public_access_deny         = false
      enable_bucket_versioning   = false
      enable_kms_encryption      = false
      enable_transfer_accelerate = false

      enable_bucket_access_log = false
      dest_bucket_name         = ""
      dest_bucket_has_policy   = false
      dest_object_prefix       = ""
    }
  }
}
