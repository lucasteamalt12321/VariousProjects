package com.example.band10companion

import android.content.Context

class HealthKitClient(
    private val context: Context,
) {
    fun getStatusText(): String {
        return "Health Kit placeholder: add developer account, app registration, and user auth flow."
    }

    fun isReady(): Boolean {
        return false
    }
}
