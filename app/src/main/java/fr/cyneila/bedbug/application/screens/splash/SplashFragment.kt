package fr.cyneila.bedbug.application.screens.splash

import android.Manifest
import android.os.Build
import androidx.fragment.app.viewModels
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.View
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.lifecycle.lifecycleScope
import androidx.navigation.fragment.findNavController
import fr.cyneila.bedbug.R
import fr.cyneila.bedbug.core.emojis
import fr.cyneila.bedbug.core.extensions.addShakyAnim
import fr.cyneila.bedbug.databinding.FragmentSplashBinding
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Currently using min api 24 so I need this Fragment in case the app isn't running in SDK > 31+\
 * Anyway I'll never use Android Splashscreen because I want stylish anim.
 * What does this SplashScreen :
 *  - Run a quick animation.
 *  - Sync some data when needed
 */
class SplashFragment : Fragment(R.layout.fragment_splash) {
    private val viewModel: SplashViewModel by viewModels()
    private var _binding: FragmentSplashBinding? = null
    private val binding get() = _binding!!

    private val permissionsLauncher =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { result ->
            val allGranted = result.values.all { it }
            if (!allGranted) {
                // Permissions have to be validated to use the app.
                showPermissionRequiredDialog()
                return@registerForActivityResult
            }
            // Start the HomeFragment after 2 seconds
            viewLifecycleOwner.lifecycleScope.launch {
                delay(2000)
                findNavController().navigate(R.id.action_splash_to_home)
            }
        }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        if (savedInstanceState != null) return
        _binding = FragmentSplashBinding.bind(view)

        val emote = emojis.random()
        binding.emote.text = emote
        binding.emoteBackground.text = emote

        binding.emote.addShakyAnim(4400, 2f)
        binding.emoteBackground.addShakyAnim(4000, 2f)
        binding.title.addShakyAnim(4400, 2f)
        binding.titleBackground.addShakyAnim(4000, 2f)

        checkPermissions()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    /**
     * Ask all permissions for BugPath Service to run.
     * I call this and force permission to be validated to run the app.
     */
    private fun checkPermissions() {
        val permissions = mutableListOf<String>()

        // Scan BLE (minAPI 26+)
        permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)

        // Android 12+ (API 31+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            permissions.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        }

        // Ask permissions.
        permissionsLauncher.launch(permissions.toTypedArray())
    }

    /**
     * Show this custom dialog everytime user refuse permissions.
     * The app cannot run without it.
     */
    private fun showPermissionRequiredDialog() {
        AlertDialog.Builder(requireContext())
            .setTitle(R.string.splash_dialog_title)
            .setMessage(R.string.splash_dialog_message)
            .setCancelable(false)
            .setPositiveButton(R.string.retry) { _, _ ->
                checkPermissions()  // Re-ask permissions.
            }
            .setNegativeButton(R.string.quit) { _, _ ->
                requireActivity().finish() // Close the app.
            }
            .show()
    }
}