provider "aws" {
  region     = "ap-south-1"
  profile    = "myprofile"
}






resource "aws_security_group" "sgbyterra" {
  name        = "sgbyterra"
  description = "Allow Tcp inbound traffic"


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security_group_terra"
  }
}




resource "tls_private_key" "weboskey12" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "mytaskkey_access"{
    content= tls_private_key.weboskey12.private_key_pem
    filename = "weboskey12.pem"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "weboskey12"
  public_key = tls_private_key.weboskey12.public_key_openssh
}





variable "mykey1" {
   default = "weboskey12"
}






resource "aws_instance" "my1stterra1" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name      = var.mykey1
  security_groups = ["sgbyterra"]




  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.weboskey12.private_key_pem
    host     = aws_instance.my1stterra1.public_ip
  }


  	provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",
      "sudo yum install php -y",
      "sudo yum install git -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
      
    ]
  }

 

  tags = {
    Name = "terraoslaunching"
  }
}









output "myav_zone" {
                   value = aws_instance.my1stterra1.availability_zone
}






resource "aws_ebs_volume" "ebsbyterra" {
  availability_zone = aws_instance.my1stterra1.availability_zone
  size              = 1

  tags = {
    Name = "myebs"
  }
}



output "myebs" {
                   value = aws_ebs_volume.ebsbyterra.id
}






resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdp"
  volume_id   =  aws_ebs_volume.ebsbyterra.id
  instance_id =  aws_instance.my1stterra1.id
  force_detach = true

}



resource "null_resource" "remote" {


  depends_on = [
    aws_volume_attachment.ebs_attach
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.weboskey12.private_key_pem
    host     = aws_instance.my1stterra1.public_ip
  }



   provisioner "remote-exec" {
      inline = [
      "sudo mkfs.ext4 /dev/xvdp",
      "sudo mount /dev/xvdp /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/MIglaniAman/awstest1.git /var/www/html/" 
      
    ]
  }
}






resource "null_resource" "local" {  

  depends_on = [
    null_resource.remote
  ]

    provisioner "local-exec"  {
       command = "chrome ${aws_instance.my1stterra1.public_ip}"
  }
}




resource "aws_s3_bucket" "bucketbyterraMIG" {
  bucket = "my-tf-test-bucket-aman-miglani-a"
  acl = "public-read"

  tags = {
    Name        = "MybucketterraA"
    Environment = "Devv"
  }
}


resource "aws_s3_bucket_object" "amanmiglaniobject" {	
  depends_on = [
    aws_s3_bucket.bucketbyterraMIG
  ]
  bucket = "my-tf-test-bucket-aman-miglani-a"
  key    = "myimage.jpg"
  source = "C:/Users/Rainbowcomputer/Desktop/MLOPS/terra/task1/myimage.jpg"
  acl = "public-read"

}


output "mys3" {
                   value = aws_s3_bucket.bucketbyterraMIG
}


output "mys31" {
                   value = aws_s3_bucket.bucketbyterraMIG.bucket_regional_domain_name
}




locals {
  s3_origin_id = "S3-my-tf-test-bucket-aman-miglani-a"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "my_irgin_acess_identity"
}


resource "aws_cloudfront_distribution" "s3_distribution_terra" {
     depends_on = [
       aws_s3_bucket_object.amanmiglaniobject,
    ]

  origin {
    domain_name = aws_s3_bucket.bucketbyterraMIG.bucket_regional_domain_name	
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true

 
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      
    }
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }
 




  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.weboskey12.private_key_pem 	
    host     = aws_instance.my1stterra1.public_ip
  }

 provisioner "remote-exec" {
    inline = [
      "sudo su <<END",
      "echo \"<img src='http://${aws_cloudfront_distribution.s3_distribution_terra.domain_name}/${aws_s3_bucket_object.amanmiglaniobject.key} 'height='200' width='200'>\" >> /var/www/html/index.html",
      "END",
    ]
  }

}







resource "null_resource" "locally" {  	

  depends_on = [
    aws_cloudfront_distribution.s3_distribution_terra
  ]

    provisioner "local-exec"  {
       command = "chrome ${aws_cloudfront_distribution.s3_distribution_terra.domain_name}/${aws_s3_bucket_object.amanmiglaniobject.key}"
  }
}








