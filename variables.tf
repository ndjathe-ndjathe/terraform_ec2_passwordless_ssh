variable "aws_region" {
  type        = string
  default     = "eu-west-3"
  description = "AWS Region"
}

variable "server_count" {
  type        = number
  default     = 3
  description = "Number of servers for the POC : Bastion + Appserver"
  validation {
    condition     = var.server_count >= 2
    error_message = "You need at least 1 Bastion and 1 Appserver"
  }
}

variable "bastion_market_type" {
  type        = string
  default     = "spot"
  description = "Market type for bastion server aws instance"
  validation {
    condition     = can(regex("^spot$|^capacity-block$", var.bastion_market_type))
    error_message = "The available market_type value are \"spot\" and \"capacity-block\". Please choose one between these values."
  }
}

variable "bastion_market_price" {
  type        = number
  default     = 0.0031
  description = "Maximum market price of the bastion server instance. Lower is better!"
}

variable "app_market_type" {
  type        = string
  default     = "spot"
  description = "Market type for app server aws instance"
  validation {
    condition     = can(regex("^spot$|^capacity-block$", var.app_market_type))
    error_message = "The available market_type value are \"spot\" and \"capacity-block\". Please choose one between these values."
  }
}

variable "app_market_price" {
  type        = number
  default     = 0.0031
  description = "Maximum market price of the app server instance. Lower is better!"
}

variable "bastion_instance_type" {
  type        = string
  default     = "t4g.nano"
  description = "AWS Instance type of bastion server"
}

variable "app_instance_type" {
  type        = string
  default     = "t4g.nano"
  description = "AWS Instance type of App servers"
}