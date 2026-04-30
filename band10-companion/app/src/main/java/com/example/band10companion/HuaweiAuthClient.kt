package com.example.band10companion

import android.content.Context

class HuaweiAuthClient(
    private val context: Context,
) {
    fun getStatusText(): String {
        return "Auth skeleton added: next step is Huawei developer console setup and user sign-in flow."
    }

    fun isSignedIn(): Boolean {
        return false
    }

    fun startSignIn() {
        // TODO: Replace with real Huawei account / service auth flow.
    }
}
