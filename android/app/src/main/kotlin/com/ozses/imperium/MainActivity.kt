package com.ozses.imperium

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity: AudioServiceActivity() {
    override fun shouldDestroyEngineWithHost(): Boolean {
        return false
    }
}

