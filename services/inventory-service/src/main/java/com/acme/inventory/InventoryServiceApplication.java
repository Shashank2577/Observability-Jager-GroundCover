package com.acme.inventory;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(scanBasePackages = {"com.acme.inventory","com.acme.observability"})
public class InventoryServiceApplication {
    public static void main(String[] args) { SpringApplication.run(InventoryServiceApplication.class, args); }
}

