package com.follow.clash.common

import android.content.ComponentName

object Components {
    const val PACKAGE_NAME = "com.yifeng.clash"

    // Class names follow the code namespace, which does not move with the
    // application id.
    const val CODE_PACKAGE = "com.follow.clash"

    val mainActivity =
        ComponentName(GlobalState.packageName, "${CODE_PACKAGE}.MainActivity")

    val quickActionActivity =
        ComponentName(GlobalState.packageName, "${CODE_PACKAGE}.QuickActionActivity")

    val serviceBroadcastReceiver =
        ComponentName(GlobalState.packageName, "${CODE_PACKAGE}.ServiceBroadcastReceiver")
}
