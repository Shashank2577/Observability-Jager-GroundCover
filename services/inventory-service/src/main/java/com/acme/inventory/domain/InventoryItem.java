package com.acme.inventory.domain;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "inventory_items")
public class InventoryItem {
    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private String id;

    @Column(name = "sku", nullable = false, unique = true)
    private String sku;

    @Column(name = "available", nullable = false)
    private int available;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public InventoryItem() {}

    public static InventoryItem create(String sku, int qty) {
        InventoryItem i = new InventoryItem();
        i.id = UUID.randomUUID().toString();
        i.sku = sku;
        i.available = qty;
        i.updatedAt = Instant.now();
        return i;
    }

    // getters/setters
    public String getId() { return id; }
    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public int getAvailable() { return available; }
    public void setAvailable(int available) { this.available = available; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}

