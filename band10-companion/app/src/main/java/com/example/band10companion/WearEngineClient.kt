package com.example.band10companion

import android.content.Context

class WearEngineClient(
    private val context: Context,
) {
    fun getStatusText(): String {
        return "Wear Engine placeholder: add Huawei service access and wearable discovery flow."
    }

    fun isReady(): Boolean {
        return false
    }

    fun getDiscoveryStatusText(): String {
        return "Discovery skeleton added: next step is calling Huawei wearable discovery APIs after service auth."
    }

    fun discoverWearables() {
        // TODO: Replace with real Wear Engine device discovery once Huawei access is configured.
    }
}
