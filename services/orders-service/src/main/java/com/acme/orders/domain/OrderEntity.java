package com.acme.orders.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "orders")
public class OrderEntity {
    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private String id;

    @Column(name = "sku", nullable = false)
    private String sku;

    @Column(name = "quantity", nullable = false)
    private int quantity;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    public OrderEntity() {}

    public static OrderEntity create(String sku, int qty) {
        OrderEntity e = new OrderEntity();
        e.id = UUID.randomUUID().toString();
        e.sku = sku;
        e.quantity = qty;
        e.status = "PENDING";
        e.createdAt = Instant.now();
        return e;
    }

    // getters & setters
    public String getId() { return id; }
    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}

