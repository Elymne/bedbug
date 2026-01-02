package fr.cyneila.bedbug.application.screens.home.pages

import androidx.fragment.app.Fragment
import fr.cyneila.bedbug.R
import org.koin.androidx.viewmodel.ext.android.viewModel

class BugPathFragment : Fragment(R.layout.fragment_bug_path) {
    private val viewModel: BugPathViewModel by viewModel()
}