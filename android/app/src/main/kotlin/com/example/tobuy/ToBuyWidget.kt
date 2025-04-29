package com.example.tobuy

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class ToBuyWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d("ToBuyWidget", "Updating widget with IDs: ${appWidgetIds.joinToString()}")
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.tobuy_widget)
            
            // Récupérer les données via HomeWidgetPlugin
            val title = HomeWidgetPlugin.getData(context).getString("title", "ToBuy Widget")
            val message = HomeWidgetPlugin.getData(context).getString("message", "Aucun article")
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_message, message)

            // Configurer le PendingIntent pour ouvrir AddItemScreen
            val intent = Intent(context, MainActivity::class.java).apply {
                putExtra("action", "openAddItem")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.add_item_button, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d("ToBuyWidget", "Widget updated for ID: $appWidgetId")
        }
    }
}