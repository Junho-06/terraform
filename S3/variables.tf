variable "buckets" {
  type        = map(any)
  description = "Map for S3 buckets"

  default = {
    mylogbucket = {
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
      dest_bucket_name         = "mytestbucket-20250207-2"
      dest_object_prefix       = "s3-accesslog/" # 끝에 / 붙여 줘야함
    }
    mytestbucket = {
      name                       = "mytestbucket-20250207-2"
      object_lock_enabled        = false
      object_ownership           = "BucketOwnerEnforced" # BucketOwnerPreferred, ObjectWriter
      acl                        = "private"             # public-read, public-read-write, aws-exec-read, authenticated-read, bucket-owner-read, bucket-owner-full-control, log-delivery-write
      public_access_deny         = false
      enable_bucket_versioning   = false
      enable_kms_encryption      = false
      enable_transfer_accelerate = false

      enable_bucket_access_log = false
    }
  }
}
