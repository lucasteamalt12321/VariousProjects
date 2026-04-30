package com.example.band10companion

import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val wearEngineClient = WearEngineClient(this)
        val healthKitClient = HealthKitClient(this)
        val huaweiAuthClient = HuaweiAuthClient(this)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
        }

        root.addView(TextView(this).apply {
            text = "Band10Companion"
            textSize = 22f
        })

        root.addView(TextView(this).apply {
            text = wearEngineClient.getStatusText()
            textSize = 16f
            setPadding(0, 24, 0, 0)
        })

        root.addView(TextView(this).apply {
            text = wearEngineClient.getDiscoveryStatusText()
            textSize = 14f
            setPadding(0, 8, 0, 0)
        })

        root.addView(TextView(this).apply {
            text = healthKitClient.getStatusText()
            textSize = 16f
            setPadding(0, 12, 0, 0)
        })

        root.addView(TextView(this).apply {
            text = huaweiAuthClient.getStatusText()
            textSize = 14f
            setPadding(0, 16, 0, 0)
        })

        root.addView(TextView(this).apply {
            text = "Next step: Huawei developer console setup and API auth"
            textSize = 14f
            setPadding(0, 24, 0, 0)
        })

        setContentView(root)
    }
}
