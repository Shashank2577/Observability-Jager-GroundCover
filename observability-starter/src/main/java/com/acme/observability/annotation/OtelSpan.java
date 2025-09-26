package com.acme.observability.annotation;

import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD})
@Documented
public @interface OtelSpan {
    String value() default ""; // Optional custom span name
}

