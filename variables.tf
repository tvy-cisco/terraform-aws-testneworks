variable "selected_network" {
  description = "Specifies which gateway to use for the private route. Valid options: 'n5', 'n4'."
  type        = string
  default     = "n5" # Default to one of the options
  validation {
    condition     = contains(["n1", "n3", "n4", "n5"], var.selected_network)
    error_message = "Valid values for selected_private_route_gateway are 'n5', 'n4', 'alt1', or 'alt2'."
  }
}