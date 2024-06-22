//
// Created by joseph on 21/06/24.
//

#ifndef NATIVE_PLATFORM_H
#define NATIVE_PLATFORM_H
#include <string>

namespace flexify {

    enum Platform {
        Linux,
        Windows
    };

    template <typename CallbackT>
    struct NotificationActionHandlers {
        CallbackT stop;
        CallbackT addOneMin;
    };

    enum Platform;
    template <Platform P>
    class TimerService;

    namespace platform_specific {

        template <Platform P, typename CallbackT>
        void nativeCodeInit(NotificationActionHandlers<CallbackT> callback);

        template <Platform P>
        TimerService<P>& getTimerService();

        template <Platform P>
        void startNativeTimer();

        template <Platform P>
        void stopNativeTimer();

        template <Platform P>
        void startAttention();

        template <Platform P>
        void stopAttention();

        template <Platform P>
        void showFinishedNotification(const std::string& description);

        template <Platform P>
        void updateCountdownNotification(const std::string& description, const std::string& remainingTime);

        template <Platform P>
        void stopNotification();

        template <Platform P>
        void sendTickPayload(int64_t* payload, size_t size);
    }
}

#endif //NATIVE_PLATFORM_H
