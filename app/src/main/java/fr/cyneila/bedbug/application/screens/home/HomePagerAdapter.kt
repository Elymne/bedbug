package fr.cyneila.bedbug.application.screens.home

import androidx.fragment.app.Fragment
import androidx.viewpager2.adapter.FragmentStateAdapter
import fr.cyneila.bedbug.application.screens.home.pages.BugPathFragment

class HomePagerAdapter(fragment: Fragment) : FragmentStateAdapter(fragment) {
    /**
     * For now, I just have one page.
     * My pager is static, always the same number of pages.
     */
    override fun getItemCount(): Int = 1

    override fun createFragment(position: Int): Fragment {
        return BugPathFragment()
    }
}