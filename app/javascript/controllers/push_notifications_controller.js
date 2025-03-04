import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="push-notifications"
export default class extends Controller {
  static targets = ["subscribeButton", "status", "toggleSwitch"]

  connect() {
    this.registerServiceWorker()
  }

  async registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.register('/service-worker')
        console.log('Service Worker registered with scope:', registration.scope)

        // Check if we already have a subscription after service worker is ready
        navigator.serviceWorker.ready.then(registration => {
          this.checkSubscription(registration)
        })
      } catch (error) {
        console.error('Service Worker registration failed:', error)
      }
    } else {
      console.log('Service workers are not supported in this browser')
    }
  }

  async checkSubscription(registration) {
    try {
      const subscription = await registration.pushManager.getSubscription()
      this.updateStatus(subscription ? 'enabled' : 'disabled')
    } catch (error) {
      console.error('Error checking subscription:', error)
      this.updateStatus('error')
    }
  }

  updateStatus(status) {
    if (this.hasStatusTarget) {
      switch (status) {
        case 'enabled':
          this.subscribeButtonTarget.checked = true
          break
        case 'disabled':
          this.subscribeButtonTarget.checked = false
          break
        case 'error':
          this.statusTarget.textContent = 'Error with push notifications'
          this.statusTarget.classList.remove('text-green-500', 'text-yellow-500')
          this.statusTarget.classList.add('text-red-500')
          this.subscribeButtonTarget.checked = false
          if (this.hasToggleSwitchTarget) {
            this.toggleSwitchTarget.classList.add('bg-red-200')
            this.toggleSwitchTarget.classList.remove('bg-gray-200', 'peer-checked:bg-sky-400')
          }
          break
      }
    }
  }

  async toggleSubscription() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
      alert('Push notifications are not supported by your browser')
      this.updateStatus('error')
      return
    }

    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (subscription) {
        // Unsubscribe
        await this.unsubscribe(subscription)
      } else {
        // Subscribe
        await this.subscribe(registration)
      }
    } catch (error) {
      console.error('Error toggling subscription:', error)
      this.updateStatus('error')

      // Reset toggle state after error
      if (this.hasToggleSwitchTarget) {
        setTimeout(() => {
          this.toggleSwitchTarget.classList.remove('bg-red-200')
          this.toggleSwitchTarget.classList.add('bg-gray-200')
          if (this.subscribeButtonTarget.checked) {
            this.toggleSwitchTarget.classList.add('peer-checked:bg-sky-400')
          }
        }, 2000)
      }
    }
  }

  async subscribe(registration) {
    try {
      // Check notification permission
      const permission = await this.requestNotificationPermission()
      if (permission !== 'granted') {
        console.log('Notification permission denied')
        this.updateStatus('error')
        return
      }

      // Get VAPID public key
      const vapidPublicKey = document.querySelector('meta[name="vapid-public-key"]')?.content

      if (!vapidPublicKey) {
        console.error('VAPID public key not found')
        this.updateStatus('error')
        return
      }

      // Convert the base64 VAPID key to Uint8Array
      const convertedVapidKey = this.urlBase64ToUint8Array(vapidPublicKey)

      // Subscribe to push
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: convertedVapidKey
      })

      // Send the subscription to the server
      await this.sendSubscriptionToServer(subscription)

      this.updateStatus('enabled')
      console.log('Subscribed to push notifications')
    } catch (error) {
      console.error('Error subscribing to push notifications:', error)
      this.updateStatus('error')
    }
  }

  async unsubscribe(subscription) {
    try {
      // Unsubscribe from push manager
      await subscription.unsubscribe()

      // Remove subscription from server
      await this.removeSubscriptionFromServer(subscription)

      this.updateStatus('disabled')
      console.log('Unsubscribed from push notifications')
    } catch (error) {
      console.error('Error unsubscribing from push notifications:', error)
    }
  }

  async requestNotificationPermission() {
    if (!('Notification' in window)) {
      console.log('Notifications not supported')
      return 'denied'
    }

    if (Notification.permission === 'granted') {
      return 'granted'
    }

    if (Notification.permission === 'denied') {
      console.log('Permission for notifications was denied')
      return 'denied'
    }

    return await Notification.requestPermission()
  }

  async sendSubscriptionToServer(subscription) {
    const token = document.querySelector('meta[name="csrf-token"]').content
    const subscriptionJson = subscription.toJSON()

    try {
      const response = await fetch('/push_subscriptions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': token
        },
        body: JSON.stringify({
          push_subscription: {
            endpoint: subscriptionJson.endpoint,
            p256dh_key: subscriptionJson.keys.p256dh,
            auth_key: subscriptionJson.keys.auth
          }
        })
      })

      if (!response.ok) {
        throw new Error('Failed to save subscription on the server')
      }
    } catch (error) {
      console.error('Error saving subscription:', error)
      throw error
    }
  }

  async removeSubscriptionFromServer(subscription) {
    const token = document.querySelector('meta[name="csrf-token"]').content
    const subscriptionJson = subscription.toJSON()

    try {
      const response = await fetch('/push_subscriptions/' + encodeURIComponent(subscriptionJson.endpoint), {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': token
        }
      })

      if (!response.ok) {
        throw new Error('Failed to remove subscription from the server')
      }
    } catch (error) {
      console.error('Error removing subscription:', error)
      throw error
    }
  }

  // Utility function to convert base64 string to Uint8Array for the applicationServerKey
  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/')

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }

    return outputArray
  }
}
