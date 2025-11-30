from django.urls import path, include
from django.contrib import admin
from app import views

urlpatterns = [
    path("", views.index, name="index"),
]
