output "sqs" {
  value = {
    URL           = aws_sqs_queue.queue.url
    ARN           = aws_sqs_queue.queue.arn
    Is_FIFO_Queue = var.sqs.FIFO_enable
  }
}
