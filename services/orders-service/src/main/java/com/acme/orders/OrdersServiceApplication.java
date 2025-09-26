package com.acme.orders;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = {"com.acme.orders","com.acme.observability"})
public class OrdersServiceApplication {
    public static void main(String[] args) { SpringApplication.run(OrdersServiceApplication.class, args); }
}

