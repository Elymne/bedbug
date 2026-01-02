package fr.cyneila.bedbug.application.screens.home

import android.content.Intent
import androidx.fragment.app.viewModels
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import fr.cyneila.bedbug.R
import fr.cyneila.bedbug.application.screens.splash.SplashFragment
import fr.cyneila.bedbug.application.services.BugPathService
import fr.cyneila.bedbug.databinding.FragmentHomeBinding
import fr.cyneila.bedbug.databinding.FragmentSplashBinding

class HomeFragment : Fragment(R.layout.fragment_home) {
    private val viewModel: HomeViewModel by viewModels()
    private var _binding: FragmentHomeBinding? = null
    private val binding get() = _binding!!

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // TODO: Start the BugPath Service.
//        val intent = Intent(requireContext(), BugPathService::class.java)
//        requireContext().startForegroundService(intent)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        if (savedInstanceState != null) return
        _binding = FragmentHomeBinding.bind(view)

        val bottomNav = binding.bottomNav

        binding.viewPager.adapter = HomePagerAdapter(this)
        binding.viewPager.isUserInputEnabled = false
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}